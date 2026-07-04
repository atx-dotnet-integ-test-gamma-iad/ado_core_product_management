# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended cross-platform .NET version (e.g., `net8.0` or `net6.0`):

```xml
<PropertyGroup>
  <TargetFramework>net8.0</TargetFramework>
</PropertyGroup>
```

If it is still referencing a Windows-only framework (e.g., `net472`), update it accordingly.

## 2. Restore and Build Locally

Run the following commands from the solution root to confirm a clean restore and build:

```bash
dotnet restore
dotnet build --configuration Release
```

Ensure there are no warnings that could indicate compatibility issues, such as platform-specific API usage.

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify that existing functionality is preserved:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests and address regressions introduced during the migration.

## 4. Check for Platform-Specific API Usage

Use the .NET Compatibility Analyzer or the `dotnet-compatibility` tool to identify any APIs that may not be supported on non-Windows platforms:

```bash
dotnet add package Microsoft.DotNet.Analyzers.Compatibility
```

Pay particular attention to any usage of:
- `System.Windows.Forms`
- `Microsoft.Win32` registry APIs
- COM interop
- P/Invoke calls targeting Windows-only libraries

## 5. Review NuGet Package Compatibility

Check that all NuGet dependencies support the target framework. Open the `.csproj` file and review `<PackageReference>` entries. For any package that does not support your target framework, look for updated versions or cross-platform alternatives on [nuget.org](https://www.nuget.org).

## 6. Test on Target Platforms

If cross-platform support is a goal, run and test the application on each intended operating system (e.g., Linux, macOS) to surface any runtime issues that static analysis may not catch:

```bash
dotnet run --configuration Release
```

## 7. Publish the Application

Once validation is complete, publish the application for the target runtime. For a self-contained deployment targeting Linux x64 as an example:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained true -o ./publish
```

For a framework-dependent deployment:

```bash
dotnet publish --configuration Release -o ./publish
```

Review the contents of the `./publish` directory to confirm all expected files are present before deploying to the target environment.