# Next Steps

The transformation appears to have completed successfully. There are no build errors present in the solution. Below are steps to validate, test, and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended cross-platform .NET version (e.g., `net8.0` or `net6.0`).

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

Review the output for any warnings that may indicate deprecated APIs or packages that could cause runtime issues even though they do not produce build errors.

## 3. Review NuGet Package Versions

Open the `.csproj` file and check that all `<PackageReference>` entries reference versions that are compatible with your target framework. Run the following to check for outdated packages:

```bash
dotnet list package --outdated
```

Update any packages that have newer stable versions available and are compatible with your target framework.

## 4. Run Existing Tests

If the solution contains test projects, execute them to verify that runtime behavior has not changed:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any test failures carefully, as they may indicate behavioral differences between the legacy .NET Framework APIs and their cross-platform .NET equivalents.

## 5. Check for Platform-Specific API Usage

Even without build errors, some APIs may have been replaced with cross-platform alternatives that behave differently at runtime. Pay particular attention to:

- File system path handling (`Path.Combine` vs hardcoded separators)
- Registry access (`Microsoft.Win32.Registry`) — not available on Linux/macOS
- Windows-specific libraries such as `System.Drawing.Common`, which requires additional configuration on non-Windows platforms
- Any use of `AppDomain`, COM interop, or P/Invoke calls

## 6. Run the Application and Perform Smoke Testing

Execute the application directly and verify core functionality:

```bash
dotnet run --project AdoCore.csproj --configuration Release
```

Walk through the primary use cases of the application to confirm that data access, business logic, and any output behave as expected.

## 7. Test on Target Platforms

If cross-platform support is a goal, run the application on each intended operating system (Windows, Linux, macOS) to surface any platform-specific runtime issues that would not appear during a Windows-only build.

## 8. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier for your deployment target:

```bash
dotnet publish --configuration Release --runtime win-x64 --self-contained false
```

Replace `win-x64` with the appropriate runtime identifier (e.g., `linux-x64`, `osx-x64`) as needed. Review the contents of the `publish` output folder before deploying to the target environment.