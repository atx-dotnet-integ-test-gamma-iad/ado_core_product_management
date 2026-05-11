# Next Steps

The transformation appears to have completed successfully. There are no build errors present in the solution. Below are steps to validate, test, and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended cross-platform .NET version (e.g., `net8.0` or `net6.0`):

```xml
<PropertyGroup>
  <TargetFramework>net8.0</TargetFramework>
</PropertyGroup>
```

If it does not match your intended target, update it and rebuild the solution.

## 2. Restore Dependencies

Run the following command from the solution root to ensure all NuGet packages are restored correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated or incompatible packages. If any packages target only `net4x` or `netstandard`, check for updated versions on [NuGet](https://www.nuget.org).

## 3. Build the Solution

Perform a clean build to confirm there are no errors:

```bash
dotnet clean
dotnet build --configuration Release
```

Review all warnings in the build output. While warnings do not block the build, they may indicate deprecated APIs or compatibility concerns that should be addressed.

## 4. Run Existing Tests

If the solution contains test projects, execute them to verify that existing functionality is preserved:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests carefully, as they may indicate behavioral differences between the legacy .NET Framework runtime and the new cross-platform .NET runtime.

## 5. Check for Runtime Compatibility Issues

Even with a clean build, certain APIs behave differently on cross-platform .NET. Manually review the code for usage of the following:

- `System.Windows.Forms` or `System.Web` — these are not fully supported cross-platform.
- `Registry` or Windows-specific file paths (e.g., `C:\Windows\...`).
- `AppDomain`, `Remoting`, or `BinaryFormatter` — these are restricted or removed in modern .NET.
- P/Invoke calls targeting Windows-only native libraries.

## 6. Test on Target Platforms

If cross-platform support is a goal, run and validate the application on each intended operating system:

```bash
# On Linux or macOS
dotnet run --configuration Release
```

Verify that file I/O, database connections, and any external integrations behave as expected on non-Windows platforms.

## 7. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier for your target environment:

```bash
# Framework-dependent (requires .NET runtime installed on target machine)
dotnet publish --configuration Release --output ./publish

# Self-contained (includes the runtime)
dotnet publish --configuration Release --runtime linux-x64 --self-contained true --output ./publish
```

Review the contents of the `./publish` directory to confirm all required files are present before deploying to the target environment.