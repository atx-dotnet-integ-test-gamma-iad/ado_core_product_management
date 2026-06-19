# Next Steps

The transformation appears to have completed successfully. There are no build errors present in the solution. Below are steps to validate, test, and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended cross-platform .NET version (e.g., `net8.0` or `net6.0`):

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

Ensure there are no warnings that could indicate compatibility issues, such as deprecated API usage or platform-specific calls.

## 3. Run Existing Tests

If a test project exists in the solution, execute the test suite to verify runtime behavior matches expectations:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests carefully, as they may indicate behavioral differences between the legacy .NET Framework runtime and the new cross-platform .NET runtime.

## 4. Check for Platform-Specific API Usage

Even if the project builds successfully, certain APIs that were available in .NET Framework may behave differently or throw `PlatformNotSupportedException` at runtime on non-Windows platforms. Use the .NET Compatibility Analyzer to identify these:

```bash
dotnet add package Microsoft.DotNet.Analyzers.Compatibility
```

Review any diagnostics produced and replace or conditionally compile platform-specific code where necessary.

## 5. Review NuGet Package Compatibility

Inspect all NuGet dependencies in `AdoCore.csproj` and confirm each package supports the target framework. You can check compatibility on [nuget.org](https://www.nuget.org) or by reviewing the `lib` folders inside each package under the global packages cache.

```bash
dotnet list package --outdated
```

Update any packages that have newer versions with cross-platform support.

## 6. Validate Database and ADO.NET Connectivity

Given the project name (`AdoCore`), it likely involves ADO.NET data access. Verify the following:

- Connection strings are correctly configured for the target environment.
- The database driver package (e.g., `Microsoft.Data.SqlClient`, `Npgsql`, `MySql.Data`) is referenced and targets the correct framework.
- Run integration or smoke tests against a real or test database instance to confirm queries execute as expected.

## 7. Test on Target Operating Systems

If cross-platform support is a goal, run the application on each intended operating system (Windows, Linux, macOS) to surface any runtime issues that do not appear during compilation:

```bash
dotnet run --configuration Release
```

Pay attention to file path separators, environment variable access, and any registry or Windows-specific calls that may have been overlooked.

## 8. Publish the Application

Once validation is complete, publish the application for the target runtime:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained false
```

Replace `linux-x64` with the appropriate runtime identifier (`win-x64`, `osx-x64`, etc.) as needed. Review the output in the `publish` folder before deploying to the target environment.