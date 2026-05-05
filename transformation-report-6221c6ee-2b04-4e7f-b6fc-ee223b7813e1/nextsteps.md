# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended .NET version (e.g., `net8.0` or `net6.0`). For example:

```xml
<PropertyGroup>
  <TargetFramework>net8.0</TargetFramework>
</PropertyGroup>
```

## 2. Restore and Build Locally

Run the following commands from the solution root to confirm a clean restore and build:

```bash
dotnet restore
dotnet build --configuration Release
```

Ensure there are no warnings that could indicate deprecated APIs or packages that may cause runtime issues.

## 3. Review NuGet Package Versions

Check that all NuGet dependencies referenced in `AdoCore.csproj` are compatible with your target framework. Run the following to identify outdated packages:

```bash
dotnet list package --outdated
```

Update any packages that have newer stable versions compatible with your target framework.

## 4. Run Existing Tests

If the solution contains test projects, execute them to verify that existing functionality has not regressed:

```bash
dotnet test --configuration Release
```

Review any failing tests and address them before proceeding.

## 5. Check for Platform-Specific API Usage

Since this was a legacy project migration, scan the codebase for any remaining Windows-specific APIs (e.g., `System.Windows.Forms`, `Microsoft.Win32`, or P/Invoke calls) that may compile successfully but fail at runtime on non-Windows platforms. The .NET Compatibility Analyzer can assist with this:

```bash
dotnet add package Microsoft.DotNet.Analyzers.Compatibility
```

## 6. Run the Application and Perform Smoke Testing

Execute the application directly and perform basic functional testing to confirm runtime behavior matches expectations:

```bash
dotnet run --project AdoCore.csproj --configuration Release
```

Manually verify core functionality, particularly any database access, file I/O, or network operations that are common in ADO-based projects.

## 7. Validate Cross-Platform Behavior (If Applicable)

If cross-platform support is a goal, test the application on each target operating system (Windows, Linux, macOS) to identify any runtime-only platform compatibility issues that static analysis may not catch.

## 8. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier for your deployment target:

```bash
dotnet publish --configuration Release --runtime win-x64 --self-contained false
```

Replace `win-x64` with the appropriate runtime identifier (e.g., `linux-x64`, `osx-x64`) as needed. Review the output in the `publish` folder before deploying to the target environment.